import PokeDataModel

extension GameRuntime {
    func handleShopItemList(
        button: RuntimeButton,
        items: [ItemManifest],
        transactionKind: RuntimeShopTransactionKind,
        state: inout RuntimeShopState
    ) {
        guard items.isEmpty == false else {
            showShopResult(
                message: shopDialogueText(id: "pokemart_item_bag_empty", fallback: "You don't have anything to sell."),
                nextPhase: .mainMenu,
                state: &state
            )
            return
        }

        let clampedIndex = max(0, min(items.count - 1, state.focusedItemIndex))
        state.focusedItemIndex = clampedIndex
        let selectedItem = items[clampedIndex]

        switch button {
        case .up:
            state.focusedItemIndex = (clampedIndex - 1 + items.count) % items.count
        case .down:
            state.focusedItemIndex = (clampedIndex + 1) % items.count
        case .confirm, .start:
            playUIConfirmSound()
            if transactionKind == .sell, canSell(item: selectedItem) == false {
                showShopFailure(.unsellableItem, state: &state)
                return
            }

            beginShopQuantitySelection(for: selectedItem, transactionKind: transactionKind, state: &state)
        case .cancel:
            playUIConfirmSound()
            returnToShopMainMenu(state: &state)
        case .left, .right:
            break
        }
    }

    func handleShopQuantitySelection(button: RuntimeButton, state: inout RuntimeShopState) {
        guard let transaction = state.transaction,
              let item = content.item(id: transaction.itemID) else {
            returnToShopMainMenu(state: &state)
            return
        }

        let maximumQuantity = maxShopQuantity(for: transaction, item: item)
        guard maximumQuantity > 0 else {
            showShopFailure(transaction.kind == .buy ? .notEnoughMoney : .emptyInventory, state: &state)
            return
        }

        switch button {
        case .up, .right:
            state.selectedQuantity = min(maximumQuantity, state.selectedQuantity + 1)
        case .down, .left:
            state.selectedQuantity = max(1, state.selectedQuantity - 1)
        case .confirm, .start:
            playUIConfirmSound()
            state.selectedQuantity = min(maximumQuantity, max(1, state.selectedQuantity))
            state.focusedConfirmationIndex = 0
            state.phase = .confirmation
            state.message = confirmationPrompt(for: item, quantity: state.selectedQuantity, kind: transaction.kind)
        case .cancel:
            playUIConfirmSound()
            transitionToShopList(for: transaction.kind, state: &state)
        }
    }

    func sellInventoryItems() -> [ItemManifest] {
        currentInventoryItems.compactMap { itemState in
            content.item(id: itemState.itemID)
        }
    }
}
