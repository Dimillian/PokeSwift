import PokeDataModel

enum BattleSelectionAction {
    case move(index: Int)
    case bag
    case partySwitch
    case run
}

extension GameRuntime {
    func battlePrompt(for phase: RuntimeBattlePhase) -> String {
        switch phase {
        case .partySelection:
            return "Bring out which #MON?"
        case .bagSelection:
            return "Choose an item."
        default:
            return "Pick the next move."
        }
    }

    func enterBattlePromptState(
        _ phase: RuntimeBattlePhase,
        battle: inout RuntimeBattleState,
        message: String? = nil
    ) {
        battle.phase = phase
        battle.message = message ?? battlePrompt(for: phase)
    }

    func returnToBattleMoveSelection(battle: inout RuntimeBattleState) {
        enterBattlePromptState(.moveSelection, battle: &battle)
    }

    func enterBattleBagSelection(battle: inout RuntimeBattleState) {
        enterBattlePromptState(.bagSelection, battle: &battle)
        battle.focusedBagItemIndex = 0
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
        enterBattlePromptState(.partySelection, battle: &battle)
        battle.partySelectionMode = mode
        battle.focusedPartyIndex = firstSwitchablePartyIndex(gameplayState: gameplayState) ?? 0
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
                battle.focusedMoveIndex = min(
                    maxBattleActionIndex(for: battle, gameplayState: gameplayState),
                    battle.focusedMoveIndex + 1
                )
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

        guard let selectedAction = focusedBattleAction(for: battle, gameplayState: gameplayState) else {
            return
        }

        switch selectedAction {
        case .bag:
            enterBattleBagSelection(battle: &battle)
            return
        case .partySwitch:
            enterOptionalBattleSwitchSelection(battle: &battle, gameplayState: gameplayState)
            return
        case .run:
            attemptBattleEscape(battle: &battle)
            return
        case let .move(index):
            guard battle.playerPokemon.moves.indices.contains(index) else {
                return
            }
            battle.focusedMoveIndex = index
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

    func availableBattleActions(
        for battle: RuntimeBattleState,
        gameplayState: GameplayState? = nil
    ) -> [BattleSelectionAction] {
        var actions = battle.playerPokemon.moves.indices.map { BattleSelectionAction.move(index: $0) }
        if canUseBattleBag(for: battle) {
            actions.append(.bag)
        }
        if let gameplayState, canUseBattleSwitch(for: battle, gameplayState: gameplayState) {
            actions.append(.partySwitch)
        }
        if battle.canRun {
            actions.append(.run)
        }
        return actions
    }

    func focusedBattleAction(
        for battle: RuntimeBattleState,
        gameplayState: GameplayState? = nil
    ) -> BattleSelectionAction? {
        let actions = availableBattleActions(for: battle, gameplayState: gameplayState)
        guard actions.indices.contains(battle.focusedMoveIndex) else {
            return nil
        }
        return actions[battle.focusedMoveIndex]
    }

    func maxBattleActionIndex(
        for battle: RuntimeBattleState,
        gameplayState: GameplayState? = nil
    ) -> Int {
        max(0, availableBattleActions(for: battle, gameplayState: gameplayState).count - 1)
    }

    func canUseBattleBag(for battle: RuntimeBattleState) -> Bool {
        battle.kind == .wild && currentBattleBagItems.isEmpty == false
    }

    func canUseBattleSwitch(for battle: RuntimeBattleState, gameplayState: GameplayState) -> Bool {
        let _ = battle
        return battleSwitchablePartyIndices(gameplayState: gameplayState).isEmpty == false
    }

    func firstSwitchablePartyIndex(gameplayState: GameplayState) -> Int? {
        battleSwitchablePartyIndices(gameplayState: gameplayState).first
    }

    func battleSwitchablePartyIndices(gameplayState: GameplayState) -> [Int] {
        gameplayState.playerParty.indices.filter { index in
            index != 0 && gameplayState.playerParty[index].currentHP > 0
        }
    }

    func battleActionIndex(
        for targetAction: BattleSelectionAction,
        battle: RuntimeBattleState,
        gameplayState: GameplayState? = nil
    ) -> Int? {
        availableBattleActions(for: battle, gameplayState: gameplayState).firstIndex { action in
            switch (action, targetAction) {
            case (.bag, .bag), (.partySwitch, .partySwitch), (.run, .run):
                return true
            case let (.move(lhs), .move(rhs)):
                return lhs == rhs
            default:
                return false
            }
        }
    }

    func bagActionIndex(for battle: RuntimeBattleState) -> Int {
        battleActionIndex(for: .bag, battle: battle, gameplayState: gameplayState) ?? battle.playerPokemon.moves.count
    }

    func switchActionIndex(for battle: RuntimeBattleState) -> Int {
        battleActionIndex(for: .partySwitch, battle: battle, gameplayState: gameplayState) ?? battle.playerPokemon.moves.count
    }

    func runActionIndex(for battle: RuntimeBattleState) -> Int {
        battleActionIndex(for: .run, battle: battle, gameplayState: gameplayState) ?? battle.playerPokemon.moves.count
    }
}
