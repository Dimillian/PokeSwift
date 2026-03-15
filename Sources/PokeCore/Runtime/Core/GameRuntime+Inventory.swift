import Foundation

extension GameRuntime {
    static let bagItemCapacity = 20
    static let maxItemStackQuantity = 99
    static let storageBoxCount = 12
    static let storageBoxCapacity = 20

    func canAddItem(_ itemID: String, quantity: Int = 1, to gameplayState: GameplayState) -> Bool {
        guard quantity > 0 else { return true }

        if let index = gameplayState.inventory.firstIndex(where: { $0.itemID == itemID }) {
            return gameplayState.inventory[index].quantity + quantity <= Self.maxItemStackQuantity
        }

        return gameplayState.inventory.count < Self.bagItemCapacity
    }

    @discardableResult
    func addItem(_ itemID: String, quantity: Int = 1, to gameplayState: inout GameplayState) -> Bool {
        guard quantity > 0, canAddItem(itemID, quantity: quantity, to: gameplayState) else {
            return false
        }

        if let index = gameplayState.inventory.firstIndex(where: { $0.itemID == itemID }) {
            gameplayState.inventory[index].quantity += quantity
        } else {
            gameplayState.inventory.append(.init(itemID: itemID, quantity: quantity))
        }

        gameplayState.inventory.sort { $0.itemID < $1.itemID }
        return true
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
    func spendMoney(_ amount: Int, from gameplayState: inout GameplayState) -> Bool {
        guard amount >= 0, gameplayState.money >= amount else { return false }
        gameplayState.money -= amount
        return true
    }

    func canAfford(_ amount: Int, gameplayState: GameplayState) -> Bool {
        amount >= 0 && gameplayState.money >= amount
    }

    @discardableResult
    func addPokemonToCurrentBox(_ pokemon: RuntimePokemonState, in gameplayState: inout GameplayState) -> Bool {
        let boxIndex = max(0, min(Self.storageBoxCount - 1, gameplayState.currentBoxIndex))
        if gameplayState.boxedPokemon.indices.contains(boxIndex) == false {
            gameplayState.boxedPokemon = (0..<Self.storageBoxCount).map { RuntimePokemonBoxState(index: $0, pokemon: []) }
        }
        guard gameplayState.boxedPokemon[boxIndex].pokemon.count < Self.storageBoxCapacity else {
            return false
        }
        gameplayState.boxedPokemon[boxIndex].pokemon.append(pokemon)
        return true
    }

    @discardableResult
    func addItem(_ itemID: String, quantity: Int = 1) -> Bool {
        guard quantity > 0, var gameplayState else { return false }
        guard addItem(itemID, quantity: quantity, to: &gameplayState) else {
            return false
        }
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

    @discardableResult
    func purchaseItem(_ itemID: String, quantity: Int) -> Bool {
        guard quantity > 0,
              var gameplayState,
              let item = content.item(id: itemID),
              canAddItem(itemID, quantity: quantity, to: gameplayState),
              spendMoney(item.price * quantity, from: &gameplayState) else {
            return false
        }

        addItem(itemID, quantity: quantity, to: &gameplayState)
        self.gameplayState = gameplayState
        traceEvent(
            .inventoryChanged,
            "Purchased \(quantity)x \(itemID).",
            mapID: gameplayState.mapID,
            details: [
                "itemID": itemID,
                "quantity": String(quantity),
                "operation": "purchase",
                "remainingMoney": String(gameplayState.money),
            ]
        )
        return true
    }
}
