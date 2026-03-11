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
                showShopResult(
                    message: shopDialogueText(id: "pokemart_unsellable_item", fallback: "I can't put a price on that."),
                    nextPhase: .mainMenu,
                    state: &state
                )
                return
            }

            state.phase = .quantity
            state.transaction = RuntimeShopTransactionState(kind: transactionKind, itemID: selectedItem.id)
            state.selectedQuantity = 1
            state.focusedConfirmationIndex = 0
            state.message = shopQuantityPrompt(for: transactionKind)
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
            showShopResult(
                message: transaction.kind == .buy
                    ? shopDialogueText(id: "pokemart_not_enough_money", fallback: "You don't have enough money.")
                    : shopDialogueText(id: "pokemart_item_bag_empty", fallback: "You don't have anything to sell."),
                nextPhase: .mainMenu,
                state: &state
            )
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
