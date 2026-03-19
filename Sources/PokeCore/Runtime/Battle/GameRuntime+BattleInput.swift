import PokeDataModel

enum BattleSelectionAction {
    case move(index: Int)
    case bag
    case partySwitch
    case run
}

extension GameRuntime {
    static let battleBagGridColumnCount = 4

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
        battle.focusedPartyIndex = firstSwitchablePartyIndex(
            gameplayState: gameplayState,
            excluding: battle.playerActiveIndex
        ) ?? 0
    }

    func enterBattleItemUseSelection(
        battle: inout RuntimeBattleState,
        gameplayState: GameplayState,
        itemID: String
    ) {
        enterBattlePromptState(
            .partySelection,
            battle: &battle,
            message: medicinePartyPromptText(itemID: itemID)
        )
        battle.partySelectionMode = .itemUse(itemID: itemID)
        battle.focusedPartyIndex = firstMedicineTargetIndex(
            itemID: itemID,
            party: gameplayState.playerParty
        ) ?? battle.playerActiveIndex
    }

    func shouldPlayBattleAdvanceConfirmSound(for battle: RuntimeBattleState) -> Bool {
        guard battle.queuedMessages.isEmpty,
              case .captured = battle.pendingAction else {
            return true
        }
        return false
    }

    func shouldPlayBattleBagConfirmSound(for battle: RuntimeBattleState) -> Bool {
        let bagItems = currentBattleBagItems
        guard bagItems.indices.contains(battle.focusedBagItemIndex),
              let item = content.item(id: bagItems[battle.focusedBagItemIndex].itemID) else {
            return true
        }
        return item.battleUse != .ball
    }

    func moveBattleBagFocusHorizontally(_ direction: Int, battle: inout RuntimeBattleState) {
        let count = currentBattleBagItems.count
        guard count > 0 else {
            battle.focusedBagItemIndex = 0
            return
        }

        let currentIndex = min(max(0, battle.focusedBagItemIndex), count - 1)
        let column = currentIndex % Self.battleBagGridColumnCount
        let rowStart = currentIndex - column
        let rowEnd = min(rowStart + Self.battleBagGridColumnCount - 1, count - 1)

        if direction < 0 {
            guard currentIndex > rowStart else { return }
            battle.focusedBagItemIndex = currentIndex - 1
        } else if direction > 0 {
            guard currentIndex < rowEnd else { return }
            battle.focusedBagItemIndex = currentIndex + 1
        }
    }

    func moveBattleBagFocusVertically(_ direction: Int, battle: inout RuntimeBattleState) {
        let count = currentBattleBagItems.count
        guard count > 0 else {
            battle.focusedBagItemIndex = 0
            return
        }

        let currentIndex = min(max(0, battle.focusedBagItemIndex), count - 1)
        let targetIndex = currentIndex + (direction * Self.battleBagGridColumnCount)
        guard (0..<count).contains(targetIndex) else {
            return
        }
        battle.focusedBagItemIndex = targetIndex
    }

    func handleBattle(button: RuntimeButton) {
        if nicknameConfirmation != nil {
            handleNicknameConfirmation(button: button)
            return
        }
        guard var gameplayState, var battle = gameplayState.battle else { return }

        switch button {
        case .up:
            switch battle.phase {
            case .moveSelection:
                battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
            case .bagSelection:
                moveBattleBagFocusVertically(-1, battle: &battle)
            case .partySelection:
                battle.focusedPartyIndex = max(0, battle.focusedPartyIndex - 1)
            case .trainerAboutToUseDecision:
                battle.focusedMoveIndex = max(0, battle.focusedMoveIndex - 1)
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
                moveBattleBagFocusVertically(1, battle: &battle)
            case .partySelection:
                battle.focusedPartyIndex = min(max(0, gameplayState.playerParty.count - 1), battle.focusedPartyIndex + 1)
            case .trainerAboutToUseDecision:
                battle.focusedMoveIndex = min(1, battle.focusedMoveIndex + 1)
            case .learnMoveDecision:
                battle.focusedMoveIndex = min(1, battle.focusedMoveIndex + 1)
            case .learnMoveSelection:
                battle.focusedMoveIndex = min(
                    max(0, battleDisplayedMoveSet(for: battle).count - 1),
                    battle.focusedMoveIndex + 1
                )
            default:
                break
            }
        case .left:
            if battle.phase == .bagSelection {
                moveBattleBagFocusHorizontally(-1, battle: &battle)
            }
        case .right:
            if battle.phase == .bagSelection {
                moveBattleBagFocusHorizontally(1, battle: &battle)
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
                switch battle.partySelectionMode {
                case .optionalSwitch:
                    playUIConfirmSound()
                    returnToBattleMoveSelection(battle: &battle)
                case .itemUse:
                    playUIConfirmSound()
                    enterBattleBagSelection(battle: &battle)
                case .forcedReplacement, .trainerShift:
                    break
                }
            case .trainerAboutToUseDecision:
                playUIConfirmSound()
                battle.focusedMoveIndex = 1
                resolveTrainerAboutToUseDecision(battle: &battle, gameplayState: &gameplayState)
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
                if battle.pendingPresentationBatches.isEmpty == false {
                    advanceBattlePresentationBatch(battle: &battle)
                } else {
                    if shouldPlayBattleAdvanceConfirmSound(for: battle) {
                        playUIConfirmSound()
                    }
                    advanceBattleText(battle: &battle)
                }
            case .moveSelection:
                playUIConfirmSound()
                resolveBattleTurn(battle: &battle, gameplayState: &gameplayState)
            case .bagSelection:
                if shouldPlayBattleBagConfirmSound(for: battle) {
                    playUIConfirmSound()
                }
                resolveBattleBagSelection(battle: &battle, gameplayState: &gameplayState)
            case .partySelection:
                playUIConfirmSound()
                resolveBattlePartySelection(battle: &battle, gameplayState: &gameplayState)
            case .trainerAboutToUseDecision:
                playUIConfirmSound()
                resolveTrainerAboutToUseDecision(battle: &battle, gameplayState: &gameplayState)
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

        // Battle text can award Pay Day money directly through self.gameplayState.
        gameplayState.money = self.gameplayState?.money ?? gameplayState.money
        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        fieldPartyReorderState = nil
        fieldItemUseState = nil
        fieldLearnMoveState = nil
        scene = .battle
        substate = "battle"
    }

    func resolveBattleTurn(battle: inout RuntimeBattleState, gameplayState: inout GameplayState) {
        guard battle.phase == .moveSelection else {
            return
        }

        if let forcedMoveIndex = forcedMoveIndex(for: battle.playerPokemon) {
            battle.focusedMoveIndex = forcedMoveIndex
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

            let batches = makeTurnPresentationBatches(for: &battle)
            guard let firstBatch = batches.first else { return }
            battle.pendingPresentationBatches = Array(batches.dropFirst())
            scheduleBattlePresentation(firstBatch, battleID: battle.battleID)
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

        let batches = makeTurnPresentationBatches(for: &battle)
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
        guard let item = content.item(id: itemState.itemID) else {
            returnToBattleMoveSelection(battle: &battle)
            battle.message = "That item can't be used here."
            return
        }

        switch item.battleUse {
        case .none:
            returnToBattleMoveSelection(battle: &battle)
            battle.message = "That item can't be used here."
            return
        case .medicine:
            guard gameplayState.playerParty.isEmpty == false else {
                returnToBattleMoveSelection(battle: &battle)
                battle.message = medicineEmptyPartyMessage
                return
            }
            guard hasUsableMedicineTarget(itemID: item.id, party: gameplayState.playerParty) else {
                returnToBattleMoveSelection(battle: &battle)
                battle.message = medicineNoEffectMessage
                return
            }
            enterBattleItemUseSelection(
                battle: &battle,
                gameplayState: gameplayState,
                itemID: item.id
            )
            return
        case .ball:
            guard removeItem(item.id, quantity: 1, from: &gameplayState) else {
                returnToBattleMoveSelection(battle: &battle)
                battle.message = "No items left."
                return
            }
        }

        battle.phase = .resolvingTurn
        battle.pendingAction = nil
        battle.pendingPresentationBatches = []
        battle.queuedMessages = []
        battle.message = ""

        switch attemptWildCapture(battle: &battle, gameplayState: &gameplayState, item: item) {
        case .handled:
            return
        case let .captured(aftermath):
            guard let captureAnimation = makeCaptureAnimation(itemID: item.id, result: .success) else {
                presentBattleMessages(
                    [captureCaughtMessage(pokemonName: battle.enemyPokemon.nickname)],
                    battle: &battle,
                    pendingAction: .captured(aftermath)
                )
                return
            }

            let caughtSoundEffect = battleSoundEffectRequest(id: "SFX_CAUGHT_MON")
            let batches = [
                makeCaptureAnimationBatch(
                    captureAnimation: captureAnimation,
                    message: captureCaughtMessage(pokemonName: battle.enemyPokemon.nickname),
                    pendingAction: .captured(aftermath),
                    soundEffectRequest: caughtSoundEffect
                )
            ]
            scheduleBattlePresentation(batches[0], battleID: battle.battleID)
            return
        case .failed:
            break
        }

        let failureMessage = captureFailureMessage(from: battle.lastCaptureResult)
        guard let captureAnimation = makeCaptureAnimation(
            itemID: item.id,
            result: battle.lastCaptureResult ?? .failed(shakes: 0)
        ) else {
            presentBattleMessages([failureMessage], battle: &battle, pendingAction: .moveSelection)
            return
        }

        let enemyResponseBatches = makeEnemyResponseBatchesAfterFailedCapture(battle: battle)
        battle.aiLayer2Encouragement += 1
        let batches = [
            makeCaptureAnimationBatch(
                captureAnimation: captureAnimation,
                message: failureMessage
            ),
        ] + enemyResponseBatches

        battle.pendingPresentationBatches = Array(batches.dropFirst())
        scheduleBattlePresentation(batches[0], battleID: battle.battleID)
    }

    func resolveTrainerAboutToUseDecision(
        battle: inout RuntimeBattleState,
        gameplayState: inout GameplayState
    ) {
        guard battle.phase == .trainerAboutToUseDecision,
              case let .aboutToUse(nextIndex, previousMoveIndex)? = battle.rewardContinuation else {
            return
        }

        battle.rewardContinuation = nil
        if battle.focusedMoveIndex == 0 {
            enterBattleSwitchSelection(
                battle: &battle,
                gameplayState: gameplayState,
                mode: .trainerShift(nextEnemyIndex: nextIndex)
            )
            return
        }

        battle.focusedMoveIndex = previousMoveIndex
        scheduleNextEnemySendOut(battle: &battle, nextIndex: nextIndex)
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
        currentBattleBagItems.isEmpty == false
    }

    func canUseBattleSwitch(for battle: RuntimeBattleState, gameplayState: GameplayState) -> Bool {
        battleSwitchablePartyIndices(
            gameplayState: gameplayState,
            excluding: battle.playerActiveIndex
        ).isEmpty == false
    }

    func firstSwitchablePartyIndex(
        gameplayState: GameplayState,
        excluding activeIndex: Int = 0
    ) -> Int? {
        battleSwitchablePartyIndices(gameplayState: gameplayState, excluding: activeIndex).first
    }

    func battleSwitchablePartyIndices(
        gameplayState: GameplayState,
        excluding activeIndex: Int = 0
    ) -> [Int] {
        gameplayState.playerParty.indices.filter { index in
            index != activeIndex && gameplayState.playerParty[index].currentHP > 0
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
