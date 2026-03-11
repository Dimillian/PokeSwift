import Foundation

extension GameRuntime {
    func addItem(_ itemID: String, quantity: Int = 1, to gameplayState: inout GameplayState) {
        guard quantity > 0 else { return }

        if let index = gameplayState.inventory.firstIndex(where: { $0.itemID == itemID }) {
            gameplayState.inventory[index].quantity += quantity
        } else {
            gameplayState.inventory.append(.init(itemID: itemID, quantity: quantity))
        }

        gameplayState.inventory.sort { $0.itemID < $1.itemID }
    }

    @discardableResult
    func removeItem(_ itemID: String, quantity: Int = 1, from gameplayState: inout GameplayState) -> Bool {
        guard quantity > 0,
              let index = gameplayState.inventory.firstIndex(where: { $0.itemID == itemID }),
              gameplayState.inventory[index].quantity >= quantity else {
            return false
        }

        gameplayState.inventory[index].quantity -= quantity
        if gameplayState.inventory[index].quantity == 0 {
            gameplayState.inventory.remove(at: index)
        }
        return true
    }

    func itemQuantity(_ itemID: String) -> Int {
        gameplayState?.inventory.first(where: { $0.itemID == itemID })?.quantity ?? 0
    }

    func hasItem(_ itemID: String) -> Bool {
        itemQuantity(itemID) > 0
    }

    @discardableResult
    func addItem(_ itemID: String, quantity: Int = 1) -> Bool {
        guard quantity > 0, var gameplayState else { return false }
        addItem(itemID, quantity: quantity, to: &gameplayState)
        self.gameplayState = gameplayState
        traceEvent(
            .inventoryChanged,
            "Added \(quantity)x \(itemID).",
            mapID: gameplayState.mapID,
            details: [
                "itemID": itemID,
                "quantity": String(quantity),
                "operation": "add",
            ]
        )
        return true
    }

    @discardableResult
    func removeItem(_ itemID: String, quantity: Int = 1) -> Bool {
        guard var gameplayState else {
            return false
        }
        guard removeItem(itemID, quantity: quantity, from: &gameplayState) else {
            return false
        }
        self.gameplayState = gameplayState
        traceEvent(
            .inventoryChanged,
            "Removed \(quantity)x \(itemID).",
            mapID: gameplayState.mapID,
            details: [
                "itemID": itemID,
                "quantity": String(quantity),
                "operation": "remove",
            ]
        )
        return true
    }
}
