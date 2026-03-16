import SwiftUI
import PokeDataModel
import PokeUI

struct ShopOverlayPanel: View {
    let shop: ShopTelemetry

    var body: some View {
        GameplayHoverCardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text(shop.title.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink)
                Text(shop.promptText.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.72))

                switch shop.phase {
                case "mainMenu":
                    ForEach(Array(shop.menuOptions.enumerated()), id: \.offset) { index, option in
                        menuRow(
                            title: option,
                            detail: nil,
                            isFocused: index == shop.focusedMainMenuIndex,
                            isSelectable: true
                        )
                    }
                case "buyList":
                    itemRows(shop.buyItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: false)
                case "sellList":
                    itemRows(shop.sellItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: true)
                case "quantity":
                    itemRows(activeItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: shop.selectedTransactionKind == "sell")
                    Text("QTY \(shop.selectedQuantity)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.68))
                case "confirmation":
                    itemRows(activeItems, focusedIndex: shop.focusedItemIndex, showsOwnedQuantity: shop.selectedTransactionKind == "sell")
                    Text("QTY \(shop.selectedQuantity)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(GameplayFieldStyleTokens.ink.opacity(0.68))
                    menuRow(title: "YES", detail: nil, isFocused: shop.focusedConfirmationIndex == 0, isSelectable: true)
                    menuRow(title: "NO", detail: nil, isFocused: shop.focusedConfirmationIndex == 1, isSelectable: true)
                default:
                    EmptyView()
                }
            }
        }
    }

    private var activeItems: [ShopRowTelemetry] {
        switch shop.selectedTransactionKind {
        case "sell":
            return shop.sellItems
        default:
            return shop.buyItems
        }
    }

    @ViewBuilder
    private func itemRows(_ items: [ShopRowTelemetry], focusedIndex: Int, showsOwnedQuantity: Bool) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.itemID) { index, item in
            menuRow(
                title: item.displayName,
                detail: itemDetail(for: item, showsOwnedQuantity: showsOwnedQuantity),
                isFocused: index == focusedIndex,
                isSelectable: item.isSelectable
            )
        }
    }

    private func itemDetail(for item: ShopRowTelemetry, showsOwnedQuantity: Bool) -> String {
        if shop.selectedTransactionKind == "sell" || shop.phase == "sellList" {
            return showsOwnedQuantity ? "x\(item.ownedQuantity) ¥\(item.transactionPrice)" : "¥\(item.transactionPrice)"
        }
        return showsOwnedQuantity ? "x\(item.ownedQuantity) ¥\(item.unitPrice)" : "¥\(item.unitPrice)"
    }

    private func menuRow(title: String, detail: String?, isFocused: Bool, isSelectable: Bool) -> some View {
        HStack(spacing: 10) {
            Text(isFocused ? "▶" : " ")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            Spacer(minLength: 8)
            if let detail {
                Text(detail.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
        }
        .foregroundStyle(
            GameplayFieldStyleTokens.ink.opacity(
                isSelectable ? (isFocused ? 1 : 0.78) : 0.38
            )
        )
    }
}
