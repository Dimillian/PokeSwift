import PokeDataModel

extension GameRuntime {
    func handleShopMainMenu(button: RuntimeButton, state: inout RuntimeShopState) {
        switch button {
        case .up, .left:
            state.focusedMainMenuIndex = (state.focusedMainMenuIndex - 1 + Self.shopMenuOptions.count) % Self.shopMenuOptions.count
        case .down, .right:
            state.focusedMainMenuIndex = (state.focusedMainMenuIndex + 1) % Self.shopMenuOptions.count
        case .confirm, .start:
            playUIConfirmSound()
            switch Self.shopMenuOptions[state.focusedMainMenuIndex] {
            case .buy:
                state.phase = .buyList
                state.transaction = nil
                state.focusedItemIndex = 0
                state.message = shopDialogueText(id: "pokemart_buying_greeting", fallback: "Take your time.")
            case .sell:
                let sellItems = sellInventoryItems()
                if sellItems.isEmpty {
                    showShopResult(
                        message: shopDialogueText(id: "pokemart_item_bag_empty", fallback: "You don't have anything to sell."),
                        nextPhase: .mainMenu,
                        state: &state
                    )
                } else {
                    state.phase = .sellList
                    state.transaction = nil
                    state.focusedItemIndex = min(state.focusedItemIndex, max(0, sellItems.count - 1))
                    state.message = shopDialogueText(id: "pokemart_selling_greeting", fallback: "What would you like to sell?")
                }
            case nil:
                closeMart()
                return
            }
        case .cancel:
            playUIConfirmSound()
            closeMart()
            return
        }
    }
}
