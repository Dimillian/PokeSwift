import PokeDataModel

extension GameRuntime {
    func confirmShopPurchase(item: ItemManifest, state: inout RuntimeShopState) {
        let quantity = min(state.selectedQuantity, maxPurchasableQuantity(for: item))
        guard quantity > 0 else {
            let hasMoney = gameplayState.map { canAfford(item.price, gameplayState: $0) } ?? false
            let message = hasMoney
                ? shopDialogueText(id: "pokemart_item_bag_full", fallback: "You can't carry any more items.")
                : shopDialogueText(id: "pokemart_not_enough_money", fallback: "You don't have enough money.")
            showShopResult(message: message, nextPhase: .mainMenu, state: &state)
            return
        }

        if purchaseItem(item.id, quantity: quantity) {
            traceEvent(
                .shopPurchase,
                "Purchased \(quantity)x \(item.id).",
                mapID: gameplayState?.mapID,
                details: [
                    "martID": state.martID,
                    "itemID": item.id,
                    "quantity": String(quantity),
                    "operation": "buy",
                ]
            )
            showShopResult(
                message: shopDialogueText(id: "pokemart_bought_item", fallback: "Here you are! Thank you!"),
                nextPhase: .buyList,
                state: &state
            )
            return
        }

        let failureMessage = (gameplayState.map { canAfford(item.price * quantity, gameplayState: $0) } ?? false)
            ? shopDialogueText(id: "pokemart_item_bag_full", fallback: "You can't carry any more items.")
            : shopDialogueText(id: "pokemart_not_enough_money", fallback: "You don't have enough money.")
        showShopResult(message: failureMessage, nextPhase: .mainMenu, state: &state)
    }

    func confirmShopSale(item: ItemManifest, state: inout RuntimeShopState) {
        guard var gameplayState else {
            showShopResult(
                message: shopDialogueText(id: "pokemart_item_bag_empty", fallback: "You don't have anything to sell."),
                nextPhase: .mainMenu,
                state: &state
            )
            return
        }

        let quantity = min(state.selectedQuantity, itemQuantity(item.id))
        guard quantity > 0 else {
            showShopResult(
                message: shopDialogueText(id: "pokemart_item_bag_empty", fallback: "You don't have anything to sell."),
                nextPhase: .mainMenu,
                state: &state
            )
            return
        }
        guard canSell(item: item) else {
            showShopResult(
                message: shopDialogueText(id: "pokemart_unsellable_item", fallback: "I can't put a price on that."),
                nextPhase: .mainMenu,
                state: &state
            )
            return
        }
        guard removeItem(item.id, quantity: quantity, from: &gameplayState) else {
            showShopResult(
                message: shopDialogueText(id: "pokemart_item_bag_empty", fallback: "You don't have anything to sell."),
                nextPhase: .mainMenu,
                state: &state
            )
            return
        }

        gameplayState.money += sellPrice(for: item) * quantity
        self.gameplayState = gameplayState
        traceEvent(
            .inventoryChanged,
            "Sold \(quantity)x \(item.id).",
            mapID: gameplayState.mapID,
            details: [
                "itemID": item.id,
                "quantity": String(quantity),
                "operation": "sell",
                "remainingMoney": String(gameplayState.money),
            ]
        )
        traceEvent(
            .shopPurchase,
            "Sold \(quantity)x \(item.id).",
            mapID: gameplayState.mapID,
            details: [
                "martID": state.martID,
                "itemID": item.id,
                "quantity": String(quantity),
                "operation": "sell",
            ]
        )
        showShopResult(
            message: shopDialogueText(id: "pokemart_anything_else", fallback: "Is there anything else I can do?"),
            nextPhase: .sellList,
            state: &state
        )
    }

    func maxPurchasableQuantity(for item: ItemManifest) -> Int {
        guard let gameplayState else { return 0 }
        guard item.price > 0 else { return 0 }

        let affordable = max(0, gameplayState.money / item.price)
        let existingQuantity = gameplayState.inventory.first(where: { $0.itemID == item.id })?.quantity ?? 0
        let stackHeadroom = max(0, Self.maxItemStackQuantity - existingQuantity)
        let hasStack = existingQuantity > 0
        let canOpenNewSlot = hasStack || gameplayState.inventory.count < Self.bagItemCapacity
        guard canOpenNewSlot else { return 0 }
        return min(Self.maxItemStackQuantity, affordable, stackHeadroom)
    }

    func maxShopQuantity(for transaction: RuntimeShopTransactionState, item: ItemManifest) -> Int {
        switch transaction.kind {
        case .buy:
            return maxPurchasableQuantity(for: item)
        case .sell:
            return itemQuantity(item.id)
        }
    }

    func canSell(item: ItemManifest) -> Bool {
        item.isKeyItem == false && item.id.hasPrefix("HM_") == false && item.price > 0
    }

    func sellPrice(for item: ItemManifest) -> Int {
        max(0, item.price / 2)
    }
}
