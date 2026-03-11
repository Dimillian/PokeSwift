import PokeDataModel

extension GameRuntime {
    func dialogueText(id: String, fallback: String) -> String {
        guard let dialogue = content.dialogue(id: id) else {
            return fallback
        }

        let lines = dialogue.pages.flatMap(\.lines)
        guard lines.isEmpty == false else {
            return fallback
        }
        return lines.joined(separator: " ")
    }

    func confirmationPrompt(for item: ItemManifest, quantity: Int, kind: RuntimeShopTransactionKind) -> String {
        let totalPrice = (kind == .buy ? item.price : sellPrice(for: item)) * quantity
        switch kind {
        case .buy:
            return "\(item.displayName)? That will be ¥\(totalPrice). OK?"
        case .sell:
            return "I can pay you ¥\(totalPrice) for that."
        }
    }

    func shopDialogueText(id: String, fallback: String) -> String {
        dialogueText(id: id, fallback: fallback)
    }
}
