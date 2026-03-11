import SwiftUI
import PokeDataModel

public struct DialogueBoxView: View {
    let title: String?
    let lines: [String]

    public init(title: String? = nil, lines: [String]) {
        self.title = title
        self.lines = lines
    }

    public var body: some View {
        GameBoyDialogueFrame {
            VStack(alignment: .leading, spacing: 8) {
                if let title {
                    GameBoyPixelText(
                        title.uppercased(),
                        scale: 1,
                        color: PokeThemePalette.tertiaryText,
                        fallbackFont: .system(size: 11, weight: .bold, design: .monospaced)
                    )
                    .padding(.bottom, 2)
                }

                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    GameBoyPixelText(
                        line,
                        scale: 2,
                        color: PokeThemePalette.primaryText,
                        fallbackFont: .system(size: 20, weight: .medium, design: .monospaced)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GameBoyDialogueFrame<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(minHeight: 92, alignment: .topLeading)
            .background {
                ZStack {
                    Rectangle()
                        .fill(PokeThemePalette.dialogueBorder)

                    Rectangle()
                        .fill(PokeThemePalette.dialoguePaper)
                        .padding(4)

                    Rectangle()
                        .fill(PokeThemePalette.dialogueInsetBorder)
                        .padding(8)

                    Rectangle()
                        .fill(PokeThemePalette.dialogueFill)
                        .padding(12)
                }
            }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(PokeThemePalette.dialogueDotSoft)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(PokeThemePalette.dialogueDotMid)
                    .frame(width: 6, height: 6)
                Rectangle()
                    .fill(PokeThemePalette.dialogueDotStrong)
                    .frame(width: 6, height: 6)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 16)
        }
        .shadow(color: PokeThemePalette.dialogueShadow, radius: 18, y: 8)
    }
}

public struct StarterChoicePanel: View {
    let options: [SpeciesManifest]
    let focusedIndex: Int

    public init(options: [SpeciesManifest], focusedIndex: Int) {
        self.options = options
        self.focusedIndex = focusedIndex
    }

    public var body: some View {
        GameBoyPanel {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose Your Starter")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundStyle(PokeThemePalette.primaryText)

                ForEach(Array(options.enumerated()), id: \.element.id) { index, species in
                    HStack(spacing: 12) {
                        Text(index == focusedIndex ? "▶" : " ")
                            .frame(width: 18, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(species.displayName)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                            Text("HP \(species.baseHP)  ATK \(species.baseAttack)  DEF \(species.baseDefense)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(index == focusedIndex ? PokeThemePalette.menuFocusFill : Color.clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .foregroundStyle(PokeThemePalette.primaryText)
        }
    }
}
