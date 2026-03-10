import SwiftUI
import PokeDataModel

public struct TitleMenuPanel: View {
    private let entries: [TitleMenuEntry]
    private let focusedIndex: Int

    public init(entries: [TitleMenuEntry], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        GameBoyPanel {
            GlassEffectContainer(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Title Menu")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.72))
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
    let entry: TitleMenuEntry
    let isFocused: Bool

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        HStack(spacing: 10) {
            Text(isFocused ? "▶" : " ")
                .frame(width: 16, alignment: .leading)
                .foregroundStyle(.black.opacity(isFocused ? 0.92 : 0.64))
            Text(entry.label)
                .foregroundStyle(entry.enabledByDefault ? .black.opacity(0.92) : .black.opacity(0.46))
            Spacer()
            if !entry.enabledByDefault {
                Text("Disabled")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.black.opacity(0.62))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.05), in: Capsule())
            }
        }
        .font(.system(size: 18, weight: .medium, design: .monospaced))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isFocused
                ? Color(red: 0.80, green: 0.90, blue: 0.73).opacity(0.30)
                : Color.white.opacity(0.12),
            in: shape
        )
        .overlay {
            shape
                .stroke(isFocused ? .black.opacity(0.14) : .black.opacity(0.07), lineWidth: 1)
        }
        .glassEffect(
            isFocused
                ? .regular.tint(Color(red: 0.77, green: 0.89, blue: 0.72).opacity(0.45))
                : .regular.tint(Color.white.opacity(0.18)),
            in: shape
        )
    }
}
