import SwiftUI

public struct FieldLearnMoveOverlayRowProps: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let detail: String?
    public let isSelectable: Bool
    public let isFocused: Bool
    public let move: PartySidebarMoveProps?

    public init(
        id: String,
        title: String,
        detail: String? = nil,
        isSelectable: Bool,
        isFocused: Bool,
        move: PartySidebarMoveProps? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isSelectable = isSelectable
        self.isFocused = isFocused
        self.move = move
    }
}

public struct FieldLearnMoveOverlayProps: Equatable, Sendable {
    public let title: String
    public let promptText: String
    public let rows: [FieldLearnMoveOverlayRowProps]

    public init(
        title: String,
        promptText: String,
        rows: [FieldLearnMoveOverlayRowProps]
    ) {
        self.title = title
        self.promptText = promptText
        self.rows = rows
    }
}

public struct FieldLearnMoveOverlay: View {
    let props: FieldLearnMoveOverlayProps

    public init(props: FieldLearnMoveOverlayProps) {
        self.props = props
    }

    public var body: some View {
        GameBoyPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text(props.title.uppercased())
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink)

                Text(props.promptText.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(FieldRetroPalette.ink.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: GameplayFieldMetrics.battleActionSpacing) {
                    ForEach(props.rows) { row in
                        if let move = row.move {
                            GameplayMoveCard(
                                props: move,
                                isSelectable: row.isSelectable,
                                isFocused: row.isFocused,
                                showsFocusIndicator: true
                            )
                        } else {
                            BattleActionSidebarRow(
                                title: row.title,
                                detail: row.detail,
                                isSelectable: row.isSelectable,
                                isFocused: row.isFocused
                            )
                        }
                    }
                }
            }
        }
    }
}
