import Foundation

public struct InventoryItemTelemetry: Codable, Equatable, Sendable {
    public let itemID: String
    public let displayName: String
    public let quantity: Int
    public let price: Int
    public let battleUse: ItemManifest.BattleUseKind

    public init(
        itemID: String,
        displayName: String,
        quantity: Int,
        price: Int = 0,
        battleUse: ItemManifest.BattleUseKind = .none
    ) {
        self.itemID = itemID
        self.displayName = displayName
        self.quantity = quantity
        self.price = price
        self.battleUse = battleUse
    }
}

public struct InventoryTelemetry: Codable, Equatable, Sendable {
    public let items: [InventoryItemTelemetry]

    public init(items: [InventoryItemTelemetry]) {
        self.items = items
    }
}

public struct ShopRowTelemetry: Codable, Equatable, Sendable {
    public let itemID: String
    public let displayName: String
    public let ownedQuantity: Int
    public let unitPrice: Int
    public let transactionPrice: Int
    public let isSelectable: Bool

    public init(
        itemID: String,
        displayName: String,
        ownedQuantity: Int,
        unitPrice: Int,
        transactionPrice: Int,
        isSelectable: Bool = true
    ) {
        self.itemID = itemID
        self.displayName = displayName
        self.ownedQuantity = ownedQuantity
        self.unitPrice = unitPrice
        self.transactionPrice = transactionPrice
        self.isSelectable = isSelectable
    }
}

public enum ShopPhaseTelemetry: String, Codable, Equatable, Sendable {
    case mainMenu
    case buyList
    case sellList
    case quantity
    case confirmation
    case result
}

public enum ShopTransactionKindTelemetry: String, Codable, Equatable, Sendable {
    case buy
    case sell
}

public struct ShopTelemetry: Codable, Equatable, Sendable {
    public let martID: String
    public let title: String
    public let phase: ShopPhaseTelemetry
    public let promptText: String
    public let focusedMainMenuIndex: Int
    public let focusedItemIndex: Int
    public let focusedConfirmationIndex: Int
    public let selectedQuantity: Int
    public let selectedTransactionKind: ShopTransactionKindTelemetry?
    public let menuOptions: [String]
    public let buyItems: [ShopRowTelemetry]
    public let sellItems: [ShopRowTelemetry]

    public init(
        martID: String,
        title: String,
        phase: ShopPhaseTelemetry,
        promptText: String,
        focusedMainMenuIndex: Int,
        focusedItemIndex: Int,
        focusedConfirmationIndex: Int,
        selectedQuantity: Int,
        selectedTransactionKind: ShopTransactionKindTelemetry?,
        menuOptions: [String],
        buyItems: [ShopRowTelemetry],
        sellItems: [ShopRowTelemetry]
    ) {
        self.martID = martID
        self.title = title
        self.phase = phase
        self.promptText = promptText
        self.focusedMainMenuIndex = focusedMainMenuIndex
        self.focusedItemIndex = focusedItemIndex
        self.focusedConfirmationIndex = focusedConfirmationIndex
        self.selectedQuantity = selectedQuantity
        self.selectedTransactionKind = selectedTransactionKind
        self.menuOptions = menuOptions
        self.buyItems = buyItems
        self.sellItems = sellItems
    }
}
