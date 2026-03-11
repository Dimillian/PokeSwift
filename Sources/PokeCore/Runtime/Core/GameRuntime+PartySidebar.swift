import Foundation

extension GameRuntime {
    func canHandleFieldPartySidebarSelection(index: Int, gameplayState: GameplayState) -> Bool {
        dialogueState == nil &&
            shopState == nil &&
            fieldTransitionState == nil &&
            scriptedMovementTask == nil &&
            gameplayState.playerParty.indices.contains(index) &&
            gameplayState.playerParty.count > 1
    }

    func canHandleBattlePartySidebarSelection(
        index: Int,
        battle: RuntimeBattleState,
        gameplayState: GameplayState
    ) -> Bool {
        battle.phase == .partySelection &&
            gameplayState.playerParty.indices.contains(index)
    }

    func clearFieldPartyReorderState() {
        guard fieldPartyReorderState != nil else { return }
        fieldPartyReorderState = nil
    }

    public func handlePartySidebarSelection(_ index: Int) {
        switch scene {
        case .field:
            handleFieldPartySidebarSelection(index)
        case .battle:
            handleBattlePartySidebarSelection(index)
        default:
            break
        }
    }

    func handleFieldPartySidebarSelection(_ index: Int) {
        guard var gameplayState,
              canHandleFieldPartySidebarSelection(index: index, gameplayState: gameplayState) else {
            return
        }

        playUIConfirmSound()

        if let reorderState = fieldPartyReorderState {
            if reorderState.selectedIndex == index {
                fieldPartyReorderState = nil
                publishSnapshot()
                return
            }

            gameplayState.playerParty.swapAt(reorderState.selectedIndex, index)
            self.gameplayState = gameplayState
            fieldPartyReorderState = nil
            publishSnapshot()
            return
        }

        fieldPartyReorderState = RuntimeFieldPartyReorderState(selectedIndex: index)
        publishSnapshot()
    }

    func handleBattlePartySidebarSelection(_ index: Int) {
        guard var gameplayState,
              var battle = gameplayState.battle,
              canHandleBattlePartySidebarSelection(index: index, battle: battle, gameplayState: gameplayState) else {
            return
        }

        battle.focusedPartyIndex = index
        resolveBattlePartySelection(battle: &battle, gameplayState: &gameplayState)

        guard scene == .battle else {
            return
        }

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        substate = "battle"
        publishSnapshot()
    }
}
