import Foundation
import PokeDataModel

extension GameRuntime {
    static let shopMenuOptions: [RuntimeShopTransactionKind?] = [.buy, .sell, nil]

    func openMart(id martID: String) {
        guard content.mart(id: martID) != nil else { return }
        clearHeldFieldDirections()
        fieldPartyReorderState = nil
        shopState = RuntimeShopState(
            martID: martID,
            phase: .mainMenu,
            focusedMainMenuIndex: 0,
            focusedItemIndex: 0,
            focusedConfirmationIndex: 0,
            selectedQuantity: 1,
            transaction: nil,
            message: shopDialogueText(id: "pokemart_greeting", fallback: "Hi there! May I help you?"),
            nextPhaseAfterResult: nil
        )
        substate = "shop_\(martID)"
        traceEvent(.shopOpened, "Opened mart \(martID).", mapID: gameplayState?.mapID, details: ["martID": martID])
    }

    func closeMart(traceCancellation: Bool = true) {
        guard let shopState else { return }
        if traceCancellation {
            traceEvent(.shopClosed, "Closed mart \(shopState.martID).", mapID: gameplayState?.mapID, details: ["martID": shopState.martID])
        }
        self.shopState = nil
        substate = "field"
    }

    func handleShop(button: RuntimeButton) {
        guard var shopState, let mart = content.mart(id: shopState.martID) else {
            closeMart(traceCancellation: false)
            return
        }

        switch shopState.phase {
        case .mainMenu:
            handleShopMainMenu(button: button, state: &shopState)
        case .buyList:
            handleShopItemList(
                button: button,
                items: mart.stockItemIDs.compactMap { content.item(id: $0) },
                transactionKind: .buy,
                state: &shopState
            )
        case .sellList:
            handleShopItemList(
                button: button,
                items: sellInventoryItems(),
                transactionKind: .sell,
                state: &shopState
            )
        case .quantity:
            handleShopQuantitySelection(button: button, state: &shopState)
        case .confirmation:
            handleShopConfirmation(button: button, state: &shopState)
        case .result:
            handleShopResult(button: button, state: &shopState)
        }

        guard self.shopState != nil else {
            return
        }
        self.shopState = shopState
    }
}
