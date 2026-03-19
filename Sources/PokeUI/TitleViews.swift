import SwiftUI
import PokeDataModel

public struct TitleMenuPanel: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    private let entries: [TitleMenuEntryState]
    private let focusedIndex: Int

    public init(entries: [TitleMenuEntryState], focusedIndex: Int) {
        self.entries = entries
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: 24, style: .continuous)

        GlassEffectContainer(spacing: 10) {
            GlassEffectContainer(spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Title Menu")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.secondaryText.color.opacity(0.92))
                        .padding(.horizontal, 8)

                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        TitleMenuRow(entry: entry, isFocused: index == focusedIndex)
                    }
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        palette.panelBackground.color.opacity(0.84),
                        palette.panelBackground.color.opacity(0.62),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: cardShape
            )
            .overlay {
                cardShape
                    .stroke(.white.opacity(0.22), lineWidth: 1)
                    .overlay {
                        cardShape
                            .inset(by: 5)
                            .stroke(palette.panelOutline.color.opacity(0.14), lineWidth: 1)
                    }
            }
            .glassEffect(
                .regular.tint(palette.panelGlassTint.color.opacity(0.8)),
                in: cardShape
            )
            .shadow(color: palette.dialogueShadow.color.opacity(0.16), radius: 18, y: 10)
        }
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}

private struct TitleMenuRow: View {
    @Environment(\.pokeAppearanceMode) private var appearanceMode
    @Environment(\.pokeGameBoyShellStyle) private var gameBoyShellStyle
    @Environment(\.colorScheme) private var colorScheme
    let entry: TitleMenuEntryState
    let isFocused: Bool

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

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
            LinearGradient(
                colors: isFocused
                    ? [
                        palette.menuFocusFill.color.opacity(0.88),
                        palette.menuFocusFill.color.opacity(0.62),
                    ]
                    : [
                        palette.menuIdleFill.color.opacity(0.66),
                        palette.menuIdleFill.color.opacity(0.42),
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: shape
        )
        .overlay {
            shape
                .stroke(
                    isFocused ? palette.menuFocusStroke.color.opacity(0.9) : palette.menuIdleStroke.color.opacity(0.55),
                    lineWidth: 1
                )
        }
        .glassEffect(
            isFocused
                ? .regular.tint(palette.menuFocusGlass.color).interactive()
                : .regular.tint(palette.menuIdleGlass.color.opacity(0.82)),
            in: shape
        )
    }

    private var palette: PokeThemeResolvedPalette {
        PokeThemePalette.resolve(
            for: appearanceMode,
            shellStyle: gameBoyShellStyle,
            colorScheme: colorScheme
        )
    }
}
