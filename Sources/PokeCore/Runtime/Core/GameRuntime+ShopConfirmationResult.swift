import PokeDataModel

extension GameRuntime {
    func beginShopQuantitySelection(
        for item: ItemManifest,
        transactionKind: RuntimeShopTransactionKind,
        state: inout RuntimeShopState
    ) {
        state.phase = .quantity
        state.transaction = RuntimeShopTransactionState(kind: transactionKind, itemID: item.id)
        state.selectedQuantity = 1
        state.focusedConfirmationIndex = 0
        state.message = shopQuantityPrompt(for: transactionKind)
    }

    func shopListPhase(for kind: RuntimeShopTransactionKind) -> RuntimeShopPhase {
        switch kind {
        case .buy:
            return .buyList
        case .sell:
            return .sellList
        }
    }

    func shopListPrompt(for kind: RuntimeShopTransactionKind) -> String {
        switch kind {
        case .buy:
            return shopDialogueText(id: "pokemart_buying_greeting", fallback: "Take your time.")
        case .sell:
            return shopDialogueText(id: "pokemart_selling_greeting", fallback: "What would you like to sell?")
        }
    }

    func shopQuantityPrompt(for kind: RuntimeShopTransactionKind) -> String {
        switch kind {
        case .buy:
            return "How many would you like?"
        case .sell:
            return "How many will you sell?"
        }
    }

    func resetShopTransactionState(state: inout RuntimeShopState) {
        state.transaction = nil
        state.selectedQuantity = 1
        state.focusedConfirmationIndex = 0
    }

    func transitionToShopList(for kind: RuntimeShopTransactionKind, state: inout RuntimeShopState) {
        state.phase = shopListPhase(for: kind)
        resetShopTransactionState(state: &state)
        state.message = shopListPrompt(for: kind)
    }

    func returnToShopPhase(_ phase: RuntimeShopPhase, state: inout RuntimeShopState) {
        switch phase {
        case .mainMenu:
            returnToShopMainMenu(state: &state)
        case .buyList:
            transitionToShopList(for: .buy, state: &state)
        case .sellList:
            transitionToShopList(for: .sell, state: &state)
        case .quantity, .confirmation, .result:
            returnToShopMainMenu(state: &state)
        }
    }

    func confirmShopTransaction(item: ItemManifest, state: inout RuntimeShopState) {
        guard let transaction = state.transaction else {
            returnToShopMainMenu(state: &state)
            return
        }

        switch transaction.kind {
        case .buy:
            confirmShopPurchase(item: item, state: &state)
        case .sell:
            confirmShopSale(item: item, state: &state)
        }
    }

    func handleShopConfirmation(button: RuntimeButton, state: inout RuntimeShopState) {
        guard let transaction = state.transaction,
              let item = content.item(id: transaction.itemID) else {
            returnToShopMainMenu(state: &state)
            return
        }

        switch button {
        case .up, .down, .left, .right:
            state.focusedConfirmationIndex = state.focusedConfirmationIndex == 0 ? 1 : 0
        case .confirm, .start:
            playUIConfirmSound()
            if state.focusedConfirmationIndex == 1 {
                transitionToShopList(for: transaction.kind, state: &state)
                return
            }

            confirmShopTransaction(item: item, state: &state)
        case .cancel:
            playUIConfirmSound()
            state.phase = .quantity
            state.message = shopQuantityPrompt(for: transaction.kind)
        }
    }

    func handleShopResult(button: RuntimeButton, state: inout RuntimeShopState) {
        switch button {
        case .confirm, .start, .cancel:
            playUIConfirmSound()
            let nextPhase = state.nextPhaseAfterResult ?? .mainMenu
            state.nextPhaseAfterResult = nil
            returnToShopPhase(nextPhase, state: &state)
        case .up, .down, .left, .right:
            break
        }
    }

    func showShopResult(
        message: String,
        nextPhase: RuntimeShopPhase,
        state: inout RuntimeShopState
    ) {
        state.phase = .result
        state.message = message
        state.nextPhaseAfterResult = nextPhase
        resetShopTransactionState(state: &state)
    }

    func returnToShopMainMenu(state: inout RuntimeShopState) {
        state.phase = .mainMenu
        resetShopTransactionState(state: &state)
        state.message = shopDialogueText(id: "pokemart_anything_else", fallback: "Is there anything else I can do?")
    }
}
