import SwiftUI
import PokeDataModel

public struct TitleMenuPanel: View {
    private let entries: [TitleMenuEntryState]
    private let focusedIndex: Int
    private let palette = PokeThemePalette.lightPalette

    public init(entries: [TitleMenuEntryState], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        GameBoyPanel {
            GlassEffectContainer(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Title Menu")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.secondaryText.color)
                        .padding(.horizontal, 6)

                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        TitleMenuRow(entry: entry, isFocused: index == focusedIndex)
                    }
                }
            }
        }
    }
}

private struct TitleMenuRow: View {
    let entry: TitleMenuEntryState
    let isFocused: Bool

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
    private let palette = PokeThemePalette.lightPalette

    var body: some View {
        HStack(spacing: 10) {
            Text(isFocused ? "▶" : " ")
                .frame(width: 16, alignment: .leading)
                .foregroundStyle(isFocused ? palette.primaryText.color : palette.secondaryText.color)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label)
                    .foregroundStyle(entry.isEnabled ? palette.primaryText.color : palette.disabledText.color)
                if let detail = entry.detail, detail.isEmpty == false {
                    Text(detail)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(palette.tertiaryText.color)
                        .lineLimit(1)
                }
            }
            Spacer()
            if !entry.isEnabled {
                Text("Disabled")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.secondaryText.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(palette.placeholderFill.color, in: Capsule())
            }
        }
        .font(.system(size: 18, weight: .medium, design: .monospaced))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isFocused
                ? palette.menuFocusFill.color
                : palette.menuIdleFill.color,
            in: shape
        )
        .overlay {
            shape
                .stroke(
                    isFocused ? palette.menuFocusStroke.color : palette.menuIdleStroke.color,
                    lineWidth: 1
                )
        }
        .glassEffect(
            isFocused
                ? .regular.tint(palette.menuFocusGlass.color)
                : .regular.tint(palette.menuIdleGlass.color),
            in: shape
        )
    }
}
