import Foundation
import PokeDataModel

extension GameRuntime {
    public func handleInventorySidebarSelection(_ itemID: String) {
        switch scene {
        case .field:
            handleFieldInventorySidebarSelection(itemID)
        case .battle:
            handleBattleInventorySidebarSelection(itemID)
        default:
            break
        }
    }

    func canHandleFieldInventorySidebarSelection(
        itemID: String,
        gameplayState: GameplayState
    ) -> Bool {
        dialogueState == nil &&
            fieldPromptState == nil &&
            fieldHealingState == nil &&
            shopState == nil &&
            fieldTransitionState == nil &&
            scriptedMovementTask == nil &&
            trainerEngagementTask == nil &&
            gameplayState.inventory.contains(where: { $0.itemID == itemID })
    }

    func handleFieldInventorySidebarSelection(_ itemID: String) {
        guard let gameplayState,
              canHandleFieldInventorySidebarSelection(itemID: itemID, gameplayState: gameplayState),
              medicineItem(for: itemID) != nil else {
            return
        }

        playUIConfirmSound()
        fieldPartyReorderState = nil

        if gameplayState.playerParty.isEmpty {
            fieldItemUseState = nil
            showFieldMedicineDialogue(
                id: "field_medicine_empty_party",
                message: medicineEmptyPartyMessage
            )
            publishSnapshot()
            return
        }

        if hasUsableMedicineTarget(itemID: itemID, party: gameplayState.playerParty) == false {
            fieldItemUseState = nil
            showFieldMedicineDialogue(
                id: "field_medicine_no_effect",
                message: medicineNoEffectMessage
            )
            publishSnapshot()
            return
        }

        fieldItemUseState = .init(itemID: itemID)
        self.gameplayState = gameplayState
        publishSnapshot()
    }

    func handleBattleInventorySidebarSelection(_ itemID: String) {
        guard var gameplayState,
              var battle = gameplayState.battle,
              battle.phase == .bagSelection,
              let itemIndex = currentBattleBagItems.firstIndex(where: { $0.itemID == itemID }) else {
            return
        }

        battle.focusedBagItemIndex = itemIndex
        if shouldPlayBattleBagConfirmSound(for: battle) {
            playUIConfirmSound()
        }
        resolveBattleBagSelection(battle: &battle, gameplayState: &gameplayState)

        guard scene == .battle else {
            return
        }

        gameplayState.playerParty = syncedPlayerParty(from: battle, gameplayState: gameplayState)
        gameplayState.battle = battle
        self.gameplayState = gameplayState
        fieldPartyReorderState = nil
        fieldItemUseState = nil
        substate = "battle"
        publishSnapshot()
    }

    func resolveFieldMedicineSelection(_ index: Int) {
        guard var gameplayState,
              let itemID = fieldItemUseState?.itemID,
              gameplayState.playerParty.indices.contains(index) else {
            return
        }

        guard let result = applyMedicine(itemID: itemID, to: gameplayState.playerParty[index]),
              removeItem(itemID, quantity: 1, from: &gameplayState) else {
            fieldItemUseState = nil
            self.gameplayState = gameplayState
            showFieldMedicineDialogue(
                id: "field_medicine_no_effect",
                message: medicineNoEffectMessage
            )
            publishSnapshot()
            return
        }

        gameplayState.playerParty[index] = result.updatedPokemon
        self.gameplayState = gameplayState
        fieldItemUseState = nil
        traceItemUseRemoval(itemID: itemID, gameplayState: gameplayState)
        showFieldMedicineDialogue(
            id: "field_medicine_\(itemID.lowercased())",
            message: result.message
        )
        publishSnapshot()
    }

    private func showFieldMedicineDialogue(id: String, message: String) {
        showInlineDialogue(
            id: id,
            pages: inlineDialoguePages(for: message),
            completion: .returnToField
        )
    }

    private func inlineDialoguePages(for message: String) -> [DialoguePage] {
        let wrappedLines = message
            .components(separatedBy: "\n")
            .flatMap { wrapBattleDialogueLine($0, limit: 18) }
            .filter { $0.isEmpty == false }

        guard wrappedLines.isEmpty == false else {
            return [.init(lines: [message], waitsForPrompt: true)]
        }

        var pages: [DialoguePage] = []
        var currentPage: [String] = []
        for line in wrappedLines {
            currentPage.append(line)
            if currentPage.count == 3 {
                pages.append(.init(lines: currentPage, waitsForPrompt: true))
                currentPage.removeAll(keepingCapacity: true)
            }
        }

        if currentPage.isEmpty == false {
            pages.append(.init(lines: currentPage, waitsForPrompt: true))
        }

        return pages
    }

    private func traceItemUseRemoval(itemID: String, gameplayState: GameplayState) {
        traceEvent(
            .inventoryChanged,
            "Removed 1x \(itemID).",
            mapID: gameplayState.mapID,
            details: [
                "itemID": itemID,
                "quantity": "1",
                "operation": "remove",
                "reason": "itemUse",
            ]
        )
    }
}
